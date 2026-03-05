/**
 * Snapshot Test Example
 *
 * スナップショットテストは、コンポーネントの出力が
 * 意図せず変更されていないことを確認するテストです。
 *
 * components/__tests__/Button.snapshot.test.tsx として配置してください。
 *
 * スナップショット更新: npx jest --updateSnapshot
 */

import { render } from '@testing-library/react';
import React from 'react';

// テスト対象のコンポーネント（例）
interface ButtonProps {
  children: React.ReactNode;
  variant?: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  loading?: boolean;
  onClick?: () => void;
}

const Button: React.FC<ButtonProps> = ({
  children,
  variant = 'primary',
  size = 'md',
  disabled = false,
  loading = false,
  onClick,
}) => {
  return (
    <button
      className={`btn btn-${variant} btn-${size}`}
      disabled={disabled || loading}
      onClick={onClick}
      aria-busy={loading}
    >
      {loading && <span className="spinner" data-testid="loading-spinner" />}
      {children}
    </button>
  );
};

describe('Button Snapshots', () => {
  describe('バリアント別', () => {
    it('primary バリアント', () => {
      const { container } = render(<Button variant="primary">Primary</Button>);
      expect(container).toMatchSnapshot();
    });

    it('secondary バリアント', () => {
      const { container } = render(<Button variant="secondary">Secondary</Button>);
      expect(container).toMatchSnapshot();
    });

    it('danger バリアント', () => {
      const { container } = render(<Button variant="danger">Danger</Button>);
      expect(container).toMatchSnapshot();
    });
  });

  describe('サイズ別', () => {
    it('small サイズ', () => {
      const { container } = render(<Button size="sm">Small</Button>);
      expect(container).toMatchSnapshot();
    });

    it('medium サイズ', () => {
      const { container } = render(<Button size="md">Medium</Button>);
      expect(container).toMatchSnapshot();
    });

    it('large サイズ', () => {
      const { container } = render(<Button size="lg">Large</Button>);
      expect(container).toMatchSnapshot();
    });
  });

  describe('状態別', () => {
    it('disabled 状態', () => {
      const { container } = render(<Button disabled>Disabled</Button>);
      expect(container).toMatchSnapshot();
    });

    it('loading 状態', () => {
      const { container } = render(<Button loading>Loading</Button>);
      expect(container).toMatchSnapshot();
    });
  });

  describe('組み合わせ', () => {
    it('primary + large + disabled', () => {
      const { container } = render(
        <Button variant="primary" size="lg" disabled>
          Primary Large Disabled
        </Button>,
      );
      expect(container).toMatchSnapshot();
    });

    it('danger + small + loading', () => {
      const { container } = render(
        <Button variant="danger" size="sm" loading>
          Danger Small Loading
        </Button>,
      );
      expect(container).toMatchSnapshot();
    });
  });
});

// カード コンポーネントの例
interface CardProps {
  title: string;
  description?: string;
  image?: string;
  footer?: React.ReactNode;
}

const Card: React.FC<CardProps> = ({ title, description, image, footer }) => {
  return (
    <div className="card">
      {image && <img src={image} alt={title} className="card-image" />}
      <div className="card-body">
        <h3 className="card-title">{title}</h3>
        {description && <p className="card-description">{description}</p>}
      </div>
      {footer && <div className="card-footer">{footer}</div>}
    </div>
  );
};

describe('Card Snapshots', () => {
  it('タイトルのみ', () => {
    const { container } = render(<Card title="Simple Card" />);
    expect(container).toMatchSnapshot();
  });

  it('タイトル + 説明', () => {
    const { container } = render(<Card title="Card with Description" description="This is a description" />);
    expect(container).toMatchSnapshot();
  });

  it('画像付き', () => {
    const { container } = render(
      <Card title="Card with Image" description="Description text" image="/placeholder.jpg" />,
    );
    expect(container).toMatchSnapshot();
  });

  it('フッター付き', () => {
    const { container } = render(
      <Card title="Card with Footer" description="Description text" footer={<Button>Action</Button>} />,
    );
    expect(container).toMatchSnapshot();
  });

  it('フル構成', () => {
    const { container } = render(
      <Card
        title="Full Card"
        description="This card has all elements"
        image="/placeholder.jpg"
        footer={
          <div>
            <Button variant="secondary" size="sm">
              Cancel
            </Button>
            <Button variant="primary" size="sm">
              Submit
            </Button>
          </div>
        }
      />,
    );
    expect(container).toMatchSnapshot();
  });
});

// インラインスナップショットの例
describe('Inline Snapshots', () => {
  it('シンプルなオブジェクトのスナップショット', () => {
    const user = {
      id: '123',
      name: 'Test User',
      role: 'admin',
    };

    // toMatchInlineSnapshot を使用すると、
    // スナップショットがテストファイル内に直接保存される
    expect(user).toMatchInlineSnapshot(`
      {
        "id": "123",
        "name": "Test User",
        "role": "admin",
      }
    `);
  });

  it('エラーメッセージのスナップショット', () => {
    const error = {
      code: 'VALIDATION_ERROR',
      message: 'Email is required',
      field: 'email',
    };

    expect(error).toMatchInlineSnapshot(`
      {
        "code": "VALIDATION_ERROR",
        "field": "email",
        "message": "Email is required",
      }
    `);
  });
});

// プロパティマッチャーを使用したスナップショット
describe('Property Matchers', () => {
  it('動的な値を含むオブジェクト', () => {
    const response = {
      id: expect.any(String),
      createdAt: expect.any(String),
      name: 'Test',
      status: 'active',
    };

    // 動的な値（id, createdAt）は any マッチャーで検証
    expect({
      id: 'abc-123',
      createdAt: new Date().toISOString(),
      name: 'Test',
      status: 'active',
    }).toMatchSnapshot(response);
  });
});
